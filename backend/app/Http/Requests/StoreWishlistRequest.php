<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreWishlistRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'game_id'      => 'required_without:rawg_id|nullable|integer',
            'rawg_id'      => 'required_without:game_id|nullable|integer',
            'harga_target' => 'required|numeric|gt:0',
            'aktif'        => 'nullable|boolean',
        ];
    }

    /**
     * Pesan validasi khusus.
     */
    public function messages(): array
    {
        return [
            'harga_target.required'         => 'Harga target wajib diisi.',
            'harga_target.numeric'          => 'Harga target harus berupa angka numerik.',
            'harga_target.gt'               => 'Harga target harus lebih besar dari 0.',
            'game_id.required_without'      => 'Parameter game_id atau rawg_id harus disertakan.',
            'rawg_id.required_without'      => 'Parameter game_id atau rawg_id harus disertakan.',
        ];
    }
}
